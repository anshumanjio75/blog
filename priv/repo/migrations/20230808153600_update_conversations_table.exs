defmodule Chatbot.Repo.Migrations.UpdateConversationsTable do
  use Ecto.Migration

  def change do
    alter table(:chatbot_conversations) do
      add :resolved_at, :utc_datetime
    end

    alter table(:chatbot_messages) do
      remove :resolved_at
    end
  end
end
