declare class DataLoader<K, V> {
  load(key: K): Promise<V>
}

interface Loaders {
  txnMetadata: DataLoader<string, LedgerTransactionMetadata | undefined | RepositoryError>
}

type GraphQLContext = {
  logger: Logger
  loaders: Loaders
  user: User | undefined
  domainAccount: Account | undefined
  ip: IpAddress | undefined
}

type GraphQLContextAuth = {
  logger: Logger
  loaders: Loaders
  user: User
  domainAccount: Account
  ip: IpAddress
  sub: string
}

// globally used types
type Logger = import("pino").Logger

declare namespace Express {
  interface Request {
    token: import("jsonwebtoken").JwtPayload
  }
}
