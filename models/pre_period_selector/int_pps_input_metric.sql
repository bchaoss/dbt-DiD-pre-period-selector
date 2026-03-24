{{ config(materialized='view') }}

{% set source_relation = ref(var('pps_metric_model')) %}

{% set ns = namespace(cols=[]) %}
{% if execute %}
  {% set ns.cols = adapter.get_columns_in_relation(source_relation) | map(attribute='name') | list %}

  {% for col in ['date', 'treated_value', 'control_value'] %}
    {% if col not in ns.cols%}
      {{ exceptions.raise_compiler_error("pps_metric_model is missing required column: '" ~ col ~ "'") }}
    {% endif %}
  {% endfor %}

  {% if 'is_holiday' not in ns.cols %}
    {{ log("pps warning: is_holiday not found in pps_metric_model, defaulting to false", info=True) }}
  {% endif %}
  {% if 'is_event' not in ns.cols %}
    {{ log("pps warning: is_event not found in pps_metric_model, defaulting to false", info=True) }}
  {% endif %}
{% endif %}

SELECT
    date,
    treated_value,
    control_value,
    {% if 'is_holiday' in ns.cols %}is_holiday{% else %}false{% endif %} AS is_holiday,
    {% if 'is_event' in ns.cols %}is_event{% else %}false{% endif %}     AS is_event
FROM {{ source_relation }}