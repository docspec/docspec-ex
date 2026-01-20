defmodule DocSpec.Test.EmptyText do
  @moduledoc """
  This module provides a list of strings that are considered empty texts, i.e. they are non-discernable: they are either invisible or look like whitespace.
  """
  @empty_texts [
    "",
    " ",
    "        ",
    nil,
    "\n",
    "\t",
    "\r",
    "\b",
    "\f",
    "\v",
    "\u0085",
    "\u00A0",
    "\u1680",
    "\u180E",
    "\u2000",
    "\u2001",
    "\u2002",
    "\u2003",
    "\u2004",
    "\u2005",
    "\u2006",
    "\u2007",
    "\u2008",
    "\u2009",
    "\u200A",
    "\u200B",
    "\u200C",
    "\u200D",
    "\u2028",
    "\u2029",
    "\u202F",
    "\u205F",
    "\u2060",
    "\u3000",
    "\uFEFF"
  ]

  @doc """
  Forms of empty texts for use in tests.

  ## Examples

      iex> DocSpec.Test.EmptyText.all() |> Enum.member?(" ")
      true
  """
  def all, do: @empty_texts
end
