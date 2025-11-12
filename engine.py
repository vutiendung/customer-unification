from jinja2 import Environment, FileSystemLoader

def render_query(config):
    env = Environment(loader=FileSystemLoader('jinja_templates'))
    template = env.get_template('match_unify.sql.j2')
    # Pass matching_rules, unify_rules, source_tables, etc.
    return template.render(
        **config
    )