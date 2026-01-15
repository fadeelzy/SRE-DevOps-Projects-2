# API Service

| Category     | SLI                                                                            | SLO                                                                             |
|--------------|--------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| Availability | total number of successful HTTP requests per minute / total number of requests | Application up 99% of the time over the last 5 days                             |
| Latency      | percentile latency of the server response over a 5 min period                  | 90% of API requests fulfilled in 100ms or less over the last 5 minutes          |
| Error Budget | number of error requests / total number of requests in budget                  | Error budget at 20% usage over the last 30 days (20% of the requests can fail)  |
| Throughput   | total number of requests over a period of time (i.e. per second)               | server handles 5 requests per second over the last 10 minutes                   |