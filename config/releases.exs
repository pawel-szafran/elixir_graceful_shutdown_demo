import Config

config :calc, Calc.Log, influxdb_base_url: System.fetch_env!("INFLUXDB_BASE_URL")
