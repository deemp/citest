defmodule Citest.Repo do
  use Ecto.Repo,
    otp_app: :citest,
    adapter: Ecto.Adapters.SQLite3
end
