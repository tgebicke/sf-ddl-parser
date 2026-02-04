CREATE OR REPLACE PROCEDURE "SP_THROW_ERROR"("MSG" VARCHAR(16777216), "ENV" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python','requests')
HANDLER = 'main'
EXTERNAL_ACCESS_INTEGRATIONS = (SLACK_WEBHOOK_ACCESS_INTEGRATION)
SECRETS = ('dev_url'=SLACK_DEV_WEBHOOK_URL,'perf_url'=SLACK_PERF_WEBHOOK_URL,'prod_url'=SLACK_PROD_WEBHOOK_URL,'crm_sdw_url'=SLACK_CRM_SDW_WEBHOOK_URL,'gov_url'=SLACK_GOV_WEBHOOK_URL)
EXECUTE AS CALLER
AS '
import snowflake.snowpark as snowpark
import json
import requests
import _snowflake
from datetime import date

def main(session, msg, env): 
    # Retrieve the Webhook URL from the SECRET object
    if env == ''PROD'':
        webhook_url = _snowflake.get_generic_secret_string(''prod_url'')
    elif env == ''PERF'':
        webhook_url = _snowflake.get_generic_secret_string(''perf_url'')
    elif env == ''GOV'':
        webhook_url = _snowflake.get_generic_secret_string(''gov_url'')
    elif env == ''CRM_SDW'':
        webhook_url = _snowflake.get_generic_secret_string(''crm_sdw_url'')
    else:
        webhook_url = _snowflake.get_generic_secret_string(''dev_url'')
    
    slack_data = {
     "text": f"Snowflake says: {msg}"
    }

    response = requests.post(
        webhook_url, data=json.dumps(slack_data),
        headers={''Content-Type'': ''application/json''}
    )
    if response.status_code != 200:
        raise ValueError(
            ''Request to slack returned an error %s, the response is:\\n%s''
            % (response.status_code, response.text)
        )
    
    return "SUCCESS"
';