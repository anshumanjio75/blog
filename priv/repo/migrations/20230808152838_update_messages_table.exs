defmodule Chatbot.Repo.Migrations.UpdateMessagesTable do
  use Ecto.Migration

  def change do
    alter table(:chatbot_messages) do
      add :resolved_at, :utc_datetime
    end
  end
end
