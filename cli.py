import click
from config import load_config
from engine import render_query


def main():
    cfg = load_config("customer.yaml")
    query = render_query(cfg)
    with open("output_query.sql", "w") as fw:
        fw.write(query)

if __name__ == '__main__':
    main()