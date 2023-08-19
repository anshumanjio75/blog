defmodule Chatbot.Chatbot do
  @moduledoc """
  The Chatbot context.
  """
  import Ecto.Query, warn: false
  alias Chatbot.Repo

  alias Chatbot.Chatbot.Conversation
  alias Chatbot.Chatbot.Message
  alias Chatbot.Chatbot.Picture
  alias Chatbot.Chatbot.OpenaiService

  def generate_chat_response(conversation, messages) do
    last_five_messages =
      Enum.slice(messages, 0..4)
      |> Enum.filter(fn message -> message.content |> String.length() < 30  end)
      |> Enum.map(fn %{role: role, content: content} ->
        %{"role" => role, "content" => content}
      end)
      |> Enum.reverse()

    create_message(conversation, OpenaiService.call_chat(last_five_messages))
  end

  def generate_image_response(conversation, messages) do
    last_five_messages =
      Enum.slice(messages, 0..4)
      |> Enum.map(fn %{role: role, content: content} ->
        %{"role" => role, "content" => content}
      end)
      |> Enum.reverse()

    create_message(conversation, OpenaiService.call_image(last_five_messages))
  end

  def list_chatbot_conversations do
    conv =
      Repo.all(Conversation)
      |> Repo.preload(:messages)

    # save_old_pictures(hd(conv))
    OpenaiService.download_and_save(hd(conv))
    # |> IO.inspect(label: "start")

    conv
  end

  def save_old_pictures(conversation) do
    conversation.messages
    |> Enum.map(fn m -> save_picture(conversation, m) end)
    |> Enum.count() |> IO.inspect(label: "urls")
  end

  defp save_picture(conversation, message) do
    case message.content |> String.split(", ") do
      arr when binary_part(hd(arr), 0, 4) == "http" ->
        arr
        # |> Enum.map(&OpenaiService.download_image(&1, conversation, message))

      _ ->
        nil
    end
  end

  @spec create_conversation(
          :invalid
          | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: any
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.changeset(attrs)
    |> Repo.update()
  end

  def create_message(conversation, attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:conversation, conversation)
    |> Repo.insert()
  end

  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_picture(conversation, message, attrs \\ %{}) do
    %Picture{}
    |> Picture.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:conversation, conversation)
    |> Ecto.Changeset.put_assoc(:message, message)
    |> Repo.insert()
  end
end
