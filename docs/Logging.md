#Logging Guidelines

We are using the following logging levels:
- error: If one of these happens the app can't run any longer. We'll see a crash somewhere, but this log will help us identifiying the cause as well.
- warning: The app can still run if one of these happens. But that doesn't mean we should ignore them. NONE of these should show in the logs, if there are any there's something terribly wrong somewhere.
- info: General information about events happening. High level and granularity, easy to read.
- debug: Low level information, things with more technical data, events that repeat a lot...
