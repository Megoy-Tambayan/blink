#!/usr/bin/env bats

load "helpers/setup-and-teardown"
load "helpers/transactions"

setup_file() {
  clear_cache
  reset_redis

  bitcoind_init
  start_trigger
  start_server

  initialize_user_from_onchain "$ALICE_TOKEN_NAME" "$ALICE_PHONE" "$ALICE_CODE"
}

teardown_file() {
  stop_trigger
  stop_server
}


@test "transactions: by account" {
  token_name="$ALICE_TOKEN_NAME"
  account_transactions_query='.data.me.defaultAccount.transactions.edges[]'

  exec_graphql "$token_name" 'transactions' '{"first": 3}'
  usd_count="$(count_transactions_by_currency \
    $account_transactions_query \
    'USD' \
  )"
  [[ "$usd_count" -gt "0" ]] || exit 1
  btc_count="$(count_transactions_by_currency \
    $account_transactions_query \
    'BTC' \
  )"
  [[ "$btc_count" -gt "0" ]] || exit 1
}

@test "transactions: by account, filtered by wallet" {
  token_name="$ALICE_TOKEN_NAME"
  usd_wallet_name="$token_name.usd_wallet_id"
  account_transactions_query='.data.me.defaultAccount.transactions.edges[]'

  variables=$(
    jq -n \
    --arg wallet_id "$(read_value $usd_wallet_name)" \
    '{"first": 3, walletIds: [$wallet_id]}'
  )
  exec_graphql "$token_name" 'transactions' "$variables"
  usd_count="$(count_transactions_by_currency \
    $account_transactions_query \
    'USD' \
  )"
  [[ "$usd_count" -gt "0" ]] || exit 1
  btc_count="$(count_transactions_by_currency \
    $account_transactions_query \
    'BTC' \
  )"
  [[ "$btc_count" == "0" ]] || exit 1
}

@test "transactions: by wallet" {
  token_name="$ALICE_TOKEN_NAME"
  btc_wallet_name="$token_name.btc_wallet_id"
  usd_wallet_name="$token_name.usd_wallet_id"

  exec_graphql "$token_name" 'transactions-by-wallet' '{"first": 3}'

  # Check for BTC wallet
  wallet_0_currency="$(currency_for_wallet 0)"
  [[ "$wallet_0_currency" == "BTC" ]] || exit 1

  wallet_0_transactions_query='.data.me.defaultAccount.wallets[0].transactions.edges[]'

  wallet_0_btc_count="$(count_transactions_by_currency \
    $wallet_0_transactions_query \
    'BTC' \
  )"
  [[ "$wallet_0_btc_count" -gt "0" ]] || exit 1

  # Check for USD wallet
  wallet_1_currency="$(currency_for_wallet 1)"
  [[ "$wallet_1_currency" == "USD" ]] || exit 1

  wallet_1_transactions_query='.data.me.defaultAccount.wallets[1].transactions.edges[]'

  wallet_1_usd_count="$(count_transactions_by_currency \
    $wallet_1_transactions_query \
    'USD' \
  )"
  [[ "$wallet_1_usd_count" -gt "0" ]] || exit 1
}
