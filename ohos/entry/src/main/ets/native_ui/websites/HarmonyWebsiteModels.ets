export class HarmonyWebsiteRecord {
  readonly websiteId: number;
  readonly domain: string;
  readonly status: string;
  readonly websiteType: string;

  constructor(data: Map<string, Object | null>) {
    this.websiteId = data.get('id') as number;
    this.domain = data.get('primaryDomain') as string;
    this.status = data.get('status') as string | null ?? '';
    this.websiteType = data.get('type') as string | null ?? '';
  }
}

export class HarmonyWebsiteOption {
  readonly optionId: number;
  readonly label: string;

  constructor(data: Map<string, Object | null>, labelKey: string = 'name') {
    this.optionId = data.get('id') as number;
    this.label = data.get(labelKey) as string;
  }
}

export interface HarmonyWebsiteLocation {
  websiteId: number;
  section: string;
}
