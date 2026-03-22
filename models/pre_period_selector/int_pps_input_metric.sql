{{ config(materialized='view') }}

{% set source_relation = ref(var('pps_metric_model')) %}
{%- if source_relation is none -%}
  {{ exceptions.raise_compiler_error("pps_metric_model is not set. Specify it in vars: pps_metric_model: 'your_staging_metric_model'") }}
{%- endif -%}

{% set cols = adapter.get_columns_in_relation(source_relation) | map(attribute='name') | list %}

{% for col in ['date', 'treated_value', 'control_value'] %}
  {% if col not in cols %}
    {{ exceptions.raise_compiler_error("pps_metric_model is missing required column: '" ~ col ~ "'") }}
  {% endif %}
{% endfor %}

{% if 'is_holiday' not in cols %}
  {{ log("pps warning: is_holiday not found in pps_metric_model, defaulting to false", info=True) }}
{% endif %}
{% if 'is_event' not in cols %}
  {{ log("pps warning: is_event not found in pps_metric_model, defaulting to false", info=True) }}
{% endif %}

SELECT
    date,
    treated_value,
    control_value,
    {% if 'is_holiday' in cols %}is_holiday{% else %}false{% endif %} AS is_holiday,
    {% if 'is_event' in cols %}is_event{% else %}false{% endif %}     AS is_event
FROM {{ source_relation }}
