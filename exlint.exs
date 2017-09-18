#!/usr/bin/env elixir

import Path
import Enum
require Logger

Code.compiler_options(ignore_module_conflict: true)

defmodule Exlint do
  @moduledoc """
  Elixir Linter.
  """

  # lib/filename.ex:19:7: F: Pipe chain should start with a raw value.
  def format({:error, {{l, c1, c2}, err, msg}}, filename)
  when is_binary(msg)
  and is_integer(l)
  and is_integer(c1)
  do
    "#{filename}:#{l}:#{c1}:#{c2}: E: #{errorformat err}#{msg}"
  end

  def format({:error, {l, err, msg}}, filename)
  when is_integer(l)
  and is_binary(msg)
  do
    "#{filename}:#{l}: E: #{errorformat err}#{msg}"
  end

  def format %CompileError{} = e, filename do
    "#{filename}:#{e.line}: E: #{e.description}"
  end

  def errorformat({a, b}) when is_binary(a) and is_binary(b) do
    "#{a} #{b}, "
  end

  def errorformat(a) when is_binary(a) do
    a
  end

  def compile ast, filename do
    try do
      Code.compile_quoted(ast, filename)

    rescue
      e -> e
    end
  end

  @doc """
  Find the project root by locating mix.exs.
  """
  def root("/") do
    {:error, "could not find mix.exs"}
  end

  def root(filename) when is_binary(filename) do
    f = dirname(filename)

    config = "#{f}/mix.exs"

    if File.exists?(config) do
      f
    else
      root(f)
    end
  end

  @doc """
  Remove all calls from the file, as they will be executed by the compiler.
  """
  def sanitize({:__block__, m, c}) do
    {
      :__block__,
      m,
      c |> map(&sanitize/1) |> reject(&is_nil/1)
    }
  end

  def sanitize({atom, _, _} = val) when is_atom atom do
    val
  end

  def sanitize(_) do
    nil
  end
end

filename = List.first System.argv

env = if filename =~ ~r/_test.exs$/, do: "test", else: "dev"

case Exlint.root(filename) do
  {:error, msg} ->
    Logger.warn msg

  root ->
    "#{root}/_build/#{env}/**/ebin"
    |> wildcard
    |> map(&Code.append_path/1)
end

with(
  {:ok, ast} <- filename
  |> File.read!
  |> Code.string_to_quoted(file: filename),

  cleanedAst <- Exlint.sanitize(ast),

  [{_, _}] <- Exlint.compile(cleanedAst, filename)
) do
  :ok
else
  error ->
    error
    |> Exlint.format(filename)
    |> IO.puts
end
