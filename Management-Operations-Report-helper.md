
# Management Operations Report helper
- _Note that sample extracted portions from the MOR are IBM Confidential._
## Problem
- Our management team requests reports monthly which include Pagerduty incident counts for decision support.
- To date, this material has been produced as follows:
  - [PagerDuty UI](https://ibm.pagerduty.com/) :arrow_right: Analytics :arrow_right: Reports
  - Select Team, then Service via checkbox:

  | Team | Service |
  |------|---------|
  |Compose Default On-call | Compose Default Sensu |
  | ICD                    | ICD Service - On-Call <br>ICD BNPP EU Oncall<br>ICD Service - Infrastructure<br>ICD Prometheus ||
  - View Incidents
  - Download CSV
  - Open in Excel
  - Create a chart, attempting a standard format (style, scales) month to month
  - Obtain other screen shots with new PagerDuty "Summary Metrics"
  - Accumulate on a PowerPoint slide
  - Add annotation to add information value and pre-address anticipated detailed inquiries

- Sample reports produced so far:

  - For ICD: The following Excel spreadsheet chart is produced from the CSV.

![ICD-PagerDuty-High-Urgency-Incidents-March-2021.png](images/ICD-PagerDuty-High-Urgency-Incidents-March-2021.png)
- Additional annotation is added from material summarized from other data sources:
  - Customer Impacting Events (CIEs): ServiceNow, "Confirmed CIEs"
  - Non-CIEs: browse Slack channel #icd-sre
![ICD-On-Call-March-2021.png](images/ICD-On-Call-March-2021.png)

- Another sample:
![ICD-On-Call-April-2021.png](images/ICD-On-Call-April-2021.png)
  - For Compose, as it is a more mature service,
    emphasis is on longer term on-call "toil reduction" through ongoing
    automation efforts.
![Highlights-Running-Compose-March-2021.png](images/Highlights-Running-Compose-March-2021.png)

## High level requirements
- daily incident count per day for date range
- simple chart suitable for PowerPoint report copy/paste without Excel use
- Single solution for ICD and Compose strongly preferred
- Nice to have:
  - semi-automated annotation
  - stack rank of top causes in descending order (Pareto: 20% of catee)
- _Note_ that there is discretion for content or formatting changes; collaboration with our management customers is encouraged.

## Possible solutions
- The scope includes ICD and Compose. A common data source of truth (PagerDuty?) is preferred.
- Approaches
  - leverage existing automation with ruby PagerDuty API usage
  - use snoopy alerts data (How is ICD handled?)
  - use PagerDuty "Dashboards" functionality (new, may have limitations or bugs)
  - separate ICD and Compose approaches, use different tools, etc.
- Original thinking (may be overly prescriptive)
  - importable directly into Excel / csv
  - Use Pagerduty API like mal
  - Smaller project to serve as tradecraft introduction
