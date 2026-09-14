# cryptocurrencies-portfolio

A Ruby on Rails + React portfolio tracker backed by the CoinMarketCap API.

## Configuration

Set the CoinMarketCap API key at runtime instead of storing credentials in source control:

```bash
export COINMARKETCAP_API_KEY="your-api-key"
```

The application fails clearly when the key is not configured. Never commit real API credentials to the repository.

## Currency Search API

`POST /search` accepts a `search` string and performs a case-insensitive substring match against currency names. Blank or missing queries return an empty result set. SQL `LIKE` metacharacters such as `%` and `_` are treated as literal search text rather than user-controlled wildcards.

Search queries are capped at 80 characters; longer values return HTTP `422` with `error.code = "invalid_search"`. Successful search responses are deterministically ordered by name and capped at 25 currencies to prevent accidental unbounded database responses.

## Valuation API

`POST /calculate` accepts a currency `id` and a positive decimal `amount`. Fractional holdings are supported.

Successful responses preserve the existing currency, current-price, amount, and calculated-value fields. Invalid, blank, zero, negative, or non-finite amounts return HTTP `422` with `error.code = "invalid_amount"` before any market-price lookup is attempted.

When CoinMarketCap is unavailable or the API key is missing, the endpoint returns HTTP `503` with `error.code = "market_data_unavailable"`. Upstream exception details and configuration values are intentionally not exposed to API clients.

## The Screenshot

![alt text](https://github.com/hoangnguyen7474/cryptocurrencies-portfolio/blob/master/app/assets/images/Screenshot%20from%202020-10-27%2019-57-26.png?raw=true)
