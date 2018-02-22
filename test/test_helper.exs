Mox.defmock(SentryMock, for: Sentry.HTTPClient)
Application.put_env(:sentry, :client, SentryMock)

ExUnit.start()
