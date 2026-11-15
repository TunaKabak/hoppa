import { getApiBaseUrl, getMerchantToken } from './merchant-auth';

export const REALTIME_WINDOW_EVENT = 'hoppa:realtime-event' as const;

export type RealtimeEventType =
  | 'NEW_ORDER'
  | 'ORDER_CANCELLED'
  | 'ORDER_STATUS_UPDATED'
  | 'COURIER_LOCATION_UPDATED'
  | 'ADMIN_ALERT';

export interface RealtimeEventEnvelope {
  id: string;
  type: RealtimeEventType;
  channel: string;
  timestamp: string;
  payload: Record<string, unknown>;
}

export type RealtimeConnectionState =
  | 'connecting'
  | 'connected'
  | 'reconnecting'
  | 'disconnected';

export interface MerchantRealtimeClientOptions {
  shopId?: string | null;
  onStateChange?: (state: RealtimeConnectionState) => void;
  onEvent?: (event: RealtimeEventEnvelope) => void;
  getToken?: () => string | null;
}

const VALID_EVENT_TYPES: ReadonlySet<string> = new Set<RealtimeEventType>([
  'NEW_ORDER',
  'ORDER_CANCELLED',
  'ORDER_STATUS_UPDATED',
  'COURIER_LOCATION_UPDATED',
  'ADMIN_ALERT',
]);

const BASE_RECONNECT_DELAY_MS = 2000;
const MAX_RECONNECT_DELAY_MS = 30000;

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function isRealtimeEventType(value: unknown): value is RealtimeEventType {
  return typeof value === 'string' && VALID_EVENT_TYPES.has(value);
}

export function isRealtimeEventEnvelope(value: unknown): value is RealtimeEventEnvelope {
  if (!isPlainObject(value)) {
    return false;
  }

  return (
    typeof value.id === 'string' &&
    isRealtimeEventType(value.type) &&
    typeof value.channel === 'string' &&
    typeof value.timestamp === 'string' &&
    isPlainObject(value.payload)
  );
}

export function buildRealtimeStreamUrl(token: string, shopId?: string | null): string {
  const baseUrl = getApiBaseUrl();
  const trimmedShopId = typeof shopId === 'string' ? shopId.trim() : '';
  const shopQuery = trimmedShopId ? `&shopId=${encodeURIComponent(trimmedShopId)}` : '';
  return `${baseUrl}/events/stream?token=${encodeURIComponent(token)}${shopQuery}`;
}

export class MerchantRealtimeClient {
  private readonly options: MerchantRealtimeClientOptions;
  private eventSource: EventSource | null = null;
  private cleanupListeners: (() => void) | null = null;
  private reconnectTimer: number | null = null;
  private reconnectAttempt = 0;
  private isManuallyDisconnected = false;
  private state: RealtimeConnectionState = 'disconnected';

  constructor(options: MerchantRealtimeClientOptions = {}) {
    this.options = options;
  }

  public getState(): RealtimeConnectionState {
    return this.state;
  }

  public connect(): void {
    if (typeof window === 'undefined' || typeof EventSource === 'undefined') {
      this.setState('disconnected');
      return;
    }

    this.isManuallyDisconnected = false;
    this.reconnectAttempt = 0;
    this.clearReconnectTimer();
    this.closeEventSource();
    this.setState('connecting');
    this.openStream();
  }

  public disconnect(): void {
    this.isManuallyDisconnected = true;
    this.reconnectAttempt = 0;
    this.clearReconnectTimer();
    this.closeEventSource();
    this.setState('disconnected');
  }

  private setState(nextState: RealtimeConnectionState): void {
    if (this.state === nextState) {
      return;
    }
    this.state = nextState;
    this.options.onStateChange?.(nextState);
  }

  private clearReconnectTimer(): void {
    if (this.reconnectTimer !== null && typeof window !== 'undefined') {
      window.clearTimeout(this.reconnectTimer);
    }
    this.reconnectTimer = null;
  }

  private closeEventSource(): void {
    if (this.cleanupListeners) {
      this.cleanupListeners();
      this.cleanupListeners = null;
    }
    if (this.eventSource) {
      this.eventSource.close();
      this.eventSource = null;
    }
  }

  private openStream(): void {
    if (this.isManuallyDisconnected) {
      return;
    }

    if (typeof window === 'undefined' || typeof EventSource === 'undefined') {
      this.setState('disconnected');
      return;
    }

    const token = this.options.getToken ? this.options.getToken() : getMerchantToken();
    if (!token) {
      this.closeEventSource();
      this.setState('disconnected');
      return;
    }

    const streamUrl = buildRealtimeStreamUrl(token, this.options.shopId);
    const es = new EventSource(streamUrl);
    this.eventSource = es;

    const handleConnected = (): void => {
      if (this.isManuallyDisconnected || this.eventSource !== es) {
        return;
      }
      this.reconnectAttempt = 0;
      this.setState('connected');
    };

    const handlePing = (): void => {
      if (this.isManuallyDisconnected || this.eventSource !== es) {
        return;
      }
      if (this.state !== 'connected') {
        this.reconnectAttempt = 0;
        this.setState('connected');
      }
    };

    es.onopen = (): void => {
      if (this.isManuallyDisconnected || this.eventSource !== es) {
        return;
      }
      this.reconnectAttempt = 0;
      this.setState('connected');
    };

    es.addEventListener('connected', handleConnected);
    es.addEventListener('ping', handlePing);

    es.onmessage = (event: MessageEvent<unknown>): void => {
      if (this.isManuallyDisconnected || this.eventSource !== es) {
        return;
      }
      if (typeof event.data !== 'string' || event.data.trim().length === 0) {
        return;
      }

      try {
        const parsed: unknown = JSON.parse(event.data);
        if (!isRealtimeEventEnvelope(parsed)) {
          return;
        }
        this.options.onEvent?.(parsed);
        if (typeof window !== 'undefined') {
          window.dispatchEvent(
            new CustomEvent<RealtimeEventEnvelope>(REALTIME_WINDOW_EVENT, {
              detail: parsed,
            })
          );
        }
      } catch (err) {
        console.error('Gerçek zamanlı SSE verisi ayrıştırılamadı:', err);
      }
    };

    es.onerror = (): void => {
      if (this.isManuallyDisconnected || this.eventSource !== es) {
        return;
      }
      // Close immediately so EventSource native retry cannot overlap with exponential backoff.
      this.closeEventSource();
      this.scheduleReconnect();
    };

    this.cleanupListeners = (): void => {
      es.removeEventListener('connected', handleConnected);
      es.removeEventListener('ping', handlePing);
      es.onopen = null;
      es.onmessage = null;
      es.onerror = null;
    };
  }

  private scheduleReconnect(): void {
    if (this.isManuallyDisconnected) {
      return;
    }

    this.clearReconnectTimer();
    const delay = Math.min(
      BASE_RECONNECT_DELAY_MS * Math.pow(2, this.reconnectAttempt),
      MAX_RECONNECT_DELAY_MS
    );
    this.reconnectAttempt += 1;
    this.setState('reconnecting');

    if (typeof window === 'undefined') {
      return;
    }

    this.reconnectTimer = window.setTimeout(() => {
      this.reconnectTimer = null;
      if (this.isManuallyDisconnected) {
        return;
      }
      this.openStream();
    }, delay);
  }
}

export function createMerchantRealtimeClient(
  options: MerchantRealtimeClientOptions = {}
): MerchantRealtimeClient {
  return new MerchantRealtimeClient(options);
}
