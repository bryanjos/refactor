defmodule RefactorTest do
  use ExUnit.Case
  doctest Refactor

  test "replace variable" do
    assert Refactor.init("""
           a = 1
           """)
           |> Refactor.find_variable_declaration(:a)
           |> Refactor.rename_to(:b)
           |> Refactor.to_source() == "b = 1"
  end

  test "replace variable instances" do
    assert Refactor.init("""
           a = 1
           a = a + 1
           """)
           |> Refactor.find_variable_declaration(:a)
           |> Refactor.rename_to(:b)
           |> Refactor.to_source() == "b = 1\nb = b + 1"
  end

  test "insert_before" do
    assert Refactor.init("""
           a = 1
           """)
           |> Refactor.find_variable_declaration(:a)
           |> Refactor.insert_before(quote do: b = 2)
           |> Refactor.to_source() == "b = 2\na = 1"
  end
end
