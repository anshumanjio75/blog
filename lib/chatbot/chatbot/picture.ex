defmodule Chatbot.Chatbot.Picture do
  use Ecto.Schema
  import Ecto.Changeset

  schema "picture" do
    field(:title, :string)
    field(:photo, :binary)
    belongs_to(:conversation, Chatbot.Chatbot.Conversation)
    belongs_to(:message, Chatbot.Chatbot.Message)

    timestamps()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:title, :photo])
    |> validate_required([:photo])
  end
end
