import crypto from "crypto";
import { Response } from "express";

export type RealtimeEventType =
  | "NEW_ORDER"
  | "ORDER_CANCELLED"
  | "ORDER_STATUS_UPDATED"
  | "COURIER_LOCATION_UPDATED"
  | "ADMIN_ALERT";

export type RealtimeEventPayload = Record<string, unknown>;

export interface RealtimeEventEnvelope<TPayload extends RealtimeEventPayload = RealtimeEventPayload> {
  id: string;
  type: RealtimeEventType;
  channel: string;
  timestamp: string;
  payload: TPayload;
}

const HEARTBEAT_INTERVAL_MS = 25_000;

export class RealtimeEventService {
  private readonly channels = new Map<string, Set<Response>>();

  /**
   * Registers an SSE Response stream on one or more channels, sends the initial
   * `connected` frame, starts a 25-second `ping` heartbeat, and returns an
   * idempotent cleanup function to prevent listener/timer leaks.
   */
  public subscribe(channels: string[], res: Response): () => void {
    const uniqueChannels = Array.from(
      new Set(channels.map((ch) => ch.trim()).filter((ch) => ch.length > 0))
    );

    for (const channel of uniqueChannels) {
      let subscribers = this.channels.get(channel);
      if (!subscribers) {
        subscribers = new Set<Response>();
        this.channels.set(channel, subscribers);
      }
      subscribers.add(res);
    }

    let cleanedUp = false;
    let heartbeatTimer: ReturnType<typeof setInterval> | null = null;

    const cleanup = (): void => {
      if (cleanedUp) {
        return;
      }
      cleanedUp = true;

      if (heartbeatTimer !== null) {
        clearInterval(heartbeatTimer);
        heartbeatTimer = null;
      }

      for (const channel of uniqueChannels) {
        const subscribers = this.channels.get(channel);
        if (!subscribers) {
          continue;
        }
        subscribers.delete(res);
        if (subscribers.size === 0) {
          this.channels.delete(channel);
        }
      }
    };

    // Send initial SSE handshake frame
    this.safeWrite(
      res,
      `event: connected\ndata: ${JSON.stringify({
        status: "ok",
        channels: uniqueChannels,
        ts: new Date().toISOString(),
      })}\n\n`,
      cleanup
    );

    // Send periodic SSE ping heartbeat every 25 seconds
    heartbeatTimer = setInterval(() => {
      if (cleanedUp || res.writableEnded || res.destroyed) {
        cleanup();
        return;
      }
      this.safeWrite(
        res,
        `event: ping\ndata: ${JSON.stringify({ ts: new Date().toISOString() })}\n\n`,
        cleanup
      );
    }, HEARTBEAT_INTERVAL_MS);

    return cleanup;
  }

  public publishToShop(
    shopId: string,
    type: RealtimeEventType,
    payload: RealtimeEventPayload
  ): void {
    if (!shopId) {
      return;
    }
    this.publishToChannel(`shop:${shopId}`, type, payload);
  }

  public publishToUser(
    userId: string,
    type: RealtimeEventType,
    payload: RealtimeEventPayload
  ): void {
    if (!userId) {
      return;
    }
    this.publishToChannel(`user:${userId}`, type, payload);
  }

  public publishToAdmin(
    type: RealtimeEventType,
    payload: RealtimeEventPayload
  ): void {
    this.publishToChannel("admin:global", type, payload);
  }

  private publishToChannel(
    channel: string,
    type: RealtimeEventType,
    payload: RealtimeEventPayload
  ): void {
    try {
      const subscribers = this.channels.get(channel);
      if (!subscribers || subscribers.size === 0) {
        return;
      }

      const envelope: RealtimeEventEnvelope = {
        id: crypto.randomUUID(),
        type,
        channel,
        timestamp: new Date().toISOString(),
        payload,
      };

      // Default SSE `message` frame (NO `event:` line) so EventSource.onmessage receives all domain events
      const frame = `data: ${JSON.stringify(envelope)}\n\n`;

      for (const res of Array.from(subscribers)) {
        if (res.writableEnded || res.destroyed) {
          subscribers.delete(res);
          if (subscribers.size === 0) {
            this.channels.delete(channel);
          }
          continue;
        }

        const ok = this.safeWrite(res, frame, () => {
          subscribers.delete(res);
          if (subscribers.size === 0) {
            this.channels.delete(channel);
          }
        });

        if (!ok) {
          subscribers.delete(res);
          if (subscribers.size === 0) {
            this.channels.delete(channel);
          }
        }
      }
    } catch (error) {
      console.error(`[RealtimeEventService] Publish error on channel ${channel}:`, error);
    }
  }

  private safeWrite(res: Response, chunk: string, onFailure: () => void): boolean {
    try {
      if (res.writableEnded || res.destroyed) {
        onFailure();
        return false;
      }
      res.write(chunk);
      const flushable = res as Response & { flush?: () => void };
      if (typeof flushable.flush === "function") {
        flushable.flush();
      }
      return true;
    } catch (error) {
      console.error("[RealtimeEventService] Stream write error:", error);
      onFailure();
      return false;
    }
  }
}

export const realtimeEventService = new RealtimeEventService();
