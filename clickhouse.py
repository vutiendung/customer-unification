from clickhouse_driver import Client

def run_query(query, host, user, password):
    client = Client(host=host, user=user, password=password)
    client.execute(query)