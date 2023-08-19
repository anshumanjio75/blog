defmodule Chatbot.Repo.Migrations.AddPictureTable do
  use Ecto.Migration

  def change do
    create table(:picture) do
      add :title, :text
      add :conversation_id, references(:chatbot_conversations, on_delete: :nothing)
      add :message_id, references(:chatbot_messages, on_delete: :nothing)
      add :photo, :binary

      timestamps  # inserted_at and updated_at
    end
  end
end
