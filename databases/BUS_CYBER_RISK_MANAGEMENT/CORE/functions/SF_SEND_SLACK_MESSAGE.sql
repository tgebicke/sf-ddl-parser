CREATE OR REPLACE FUNCTION "SF_SEND_SLACK_MESSAGE"("MSG" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python','requests')
HANDLER = 'main'
EXTERNAL_ACCESS_INTEGRATIONS = (SLACK_WEBHOOK_ACCESS_INTEGRATION_CRM)
SECRETS = ('crm_sdw_url'=SLACK_CRM_SDW_WEBHOOK_URL)
AS '
import snowflake.snowpark as snowpark
import json
import requests
import _snowflake
from datetime import date

def main(msg): 
    # Retrieve the Webhook URL from the SECRET object
    webhook_url = _snowflake.get_generic_secret_string(''crm_sdw_url'')
    
    slack_data = {
     "text": f"Snowflake alert: {msg}"
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