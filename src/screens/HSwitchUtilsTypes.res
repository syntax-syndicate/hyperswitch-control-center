type browserDetailsObject = {
  userAgent: string,
  browserVersion: string,
  platform: string,
  browserName: string,
  browserLanguage: string,
  screenHeight: string,
  screenWidth: string,
  timeZoneOffset: string,
  clientCountry: Country.timezoneType,
}

type pageLevelVariant =
  | HOME
  | PAYMENTS
  | REFUNDS
  | DISPUTES
  | CONNECTOR
  | ROUTING
  | ANALYTICS_PAYMENTS
  | ANALYTICS_REFUNDS
  | SETTINGS
  | DEVELOPERS

type textVariantType =
  | H1
  | H2
  | H3
  | P1
  | P2
  | P3

type subVariantType = Regular | Medium | Leading_1 | Leading_2 | Optional

type bannerType = Success | Warning | Error | Info
