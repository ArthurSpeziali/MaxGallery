ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(MaxGallery.Repo, :manual)

# Start the storage mock for tests
MaxGallery.Storage.Mock.start_link()
