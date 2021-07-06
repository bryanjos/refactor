defmodule Refactor do
  @moduledoc """
  Documentation for `Refactor`.

  No need for node functions since we have quote.

  """

  defmodule Context do
    defstruct source: nil, commands: []
  end

  def init(source) do
    %Context{source: source, commands: []}
  end

  def find_variable_declaration(context, variable_name) do
    %{context | commands: context.commands ++ [{:find_variable_declaration, variable_name}]}
  end

  def insert_before(context, ast) do
    %{context | commands: context.commands ++ [{:insert_before, ast}]}
  end

  def rename_to(context, new_variable_name) do
    %{context | commands: context.commands ++ [{:rename_variable, new_variable_name}]}
  end

  @doc """
  """
  def to_source(context) do
    commands = compress_commands(context.commands, [])

    %Context{source: source, commands: commands} = %{context | commands: commands}

    ast = Sourceror.parse_string!(source)

    ast = Enum.reduce(commands, ast, fn command, ast -> process_command(command, ast) end)

    Sourceror.to_string(ast)
  end

  defp compress_commands(
         [{:find_variable_declaration, variable_name}, {:insert_before, ast} | commands],
         processed_commands
       ) do
    processed_commands = processed_commands ++ [{:insert_before, variable_name, ast}]
    compress_commands(commands, processed_commands)
  end

  defp compress_commands(
         [
           {:find_variable_declaration, variable_name},
           {:rename_variable, new_variable_name} | commands
         ],
         processed_commands
       ) do
    processed_commands =
      processed_commands ++ [{:rename_variable, variable_name, new_variable_name}]

    compress_commands(commands, processed_commands)
  end

  defp compress_commands([], processed_commands) do
    processed_commands
  end

  defp compress_commands([command], processed_commands) do
    processed_commands ++ [command]
  end

  defp process_command({:rename_variable, variable_name, new_variable_name}, ast) do
    Sourceror.postwalk(ast, fn
      {^variable_name, b, c}, state -> {{new_variable_name, b, c}, state}
      node, state -> {node, state}
    end)
  end

  defp process_command({:insert_before, variable_name, new_ast}, ast) do
    Sourceror.postwalk(ast, fn
      {:=, _, [{^variable_name, _, _}, _]} = variable, state ->
        {{:__block__, [],
          [
            new_ast,
            variable
          ]}, state}

      node, state ->
        {node, state}
    end)
  end

  defp process_command(_, ast) do
    ast
  end
end
