import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface RouteStop {
  type: 'PICKUP' | 'DELIVERY';
  name: string;
  latitude: number;
  longitude: number;
  orderId?: string;
}

export interface OptimizedBatch {
  shopId: string;
  shopName: string;
  orders: {
    id: string;
    consumerName: string;
    status: string;
  }[];
  route: RouteStop[];
  totalDistanceKm: number;
  estimatedPrepTimeMins: number;
  totalCostScore: number;
}

export class BatchingService {

  // Haversine distance calculator (km)
  private static calculateHaversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Earth radius in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Optimizes unassigned orders by clustering them into batches of 2-3 orders
   * based on Shop locations and delivery proximity.
   */
  public static async optimizeBatches(): Promise<OptimizedBatch[]> {
    // 1. Fetch unassigned orders that require delivery
    const orders = await prisma.order.findMany({
      where: {
        status: { in: ['PENDING', 'PREPARING'] },
        courierId: null,
        deliveryType: 'DELIVERY'
      },
      include: {
        shop: { select: { id: true, name: true, latitude: true, longitude: true } },
        address: { select: { latitude: true, longitude: true, title: true, fullAddress: true } },
        consumer: { select: { name: true } }
      }
    });

    if (orders.length === 0) return [];

    // 2. Group orders by Shop
    const ordersByShop: Record<string, typeof orders> = {};
    for (const order of orders) {
      if (!order.shop.latitude || !order.shop.longitude || !order.address.latitude || !order.address.longitude) {
        continue;
      }
      if (!ordersByShop[order.shopId]) {
        ordersByShop[order.shopId] = [];
      }
      ordersByShop[order.shopId].push(order);
    }

    const recommendedBatches: OptimizedBatch[] = [];

    // 3. For each shop, optimize delivery grouping
    for (const shopId of Object.keys(ordersByShop)) {
      const shopOrders = ordersByShop[shopId];
      const shop = shopOrders[0].shop;
      const shopName = shop.name ?? "Bilinmeyen Dükkan";

      const shopLat = shop.latitude!;
      const shopLon = shop.longitude!;

      // We will perform clustering
      const visited = new Set<string>();

      for (let i = 0; i < shopOrders.length; i++) {
        const orderA = shopOrders[i];
        if (visited.has(orderA.id)) continue;

        // Try to find a close neighbor order from the same shop
        let bestNeighbor: typeof orderA | null = null;
        let minNeighborDist = Infinity;

        for (let j = i + 1; j < shopOrders.length; j++) {
          const orderB = shopOrders[j];
          if (visited.has(orderB.id)) continue;

          // Distance between delivery addresses
          const distBetween = this.calculateHaversine(
            orderA.address.latitude!,
            orderA.address.longitude!,
            orderB.address.latitude!,
            orderB.address.longitude!
          );

          // Proximity threshold is 3.5 km
          if (distBetween < 3.5 && distBetween < minNeighborDist) {
            bestNeighbor = orderB;
            minNeighborDist = distBetween;
          }
        }

        const currentBatch = [orderA];
        visited.add(orderA.id);

        if (bestNeighbor) {
          currentBatch.push(bestNeighbor);
          visited.add(bestNeighbor.id);
        }

        // Calculate optimal route sequence & cost score
        // C(R) = Sum(d(p_i, p_i+1)) + PrepTime
        const estimatedPrepTime = 15; // Assume 15 minutes average prep time

        if (currentBatch.length === 1) {
          const single = currentBatch[0];
          const dist = this.calculateHaversine(
            shopLat, shopLon,
            single.address.latitude!, single.address.longitude!
          );

          recommendedBatches.push({
            shopId,
            shopName,
            orders: [{ id: single.id, consumerName: single.consumer.name ?? "Müşteri", status: single.status }],
            route: [
              { type: 'PICKUP', name: shopName, latitude: shopLat, longitude: shopLon },
              { type: 'DELIVERY', name: single.address.title || 'Müşteri', latitude: single.address.latitude!, longitude: single.address.longitude!, orderId: single.id }
            ],
            totalDistanceKm: Number(dist.toFixed(2)),
            estimatedPrepTimeMins: estimatedPrepTime,
            totalCostScore: Number((dist + estimatedPrepTime / 10).toFixed(2))
          });
        } else {
          // Compare routing variants: Shop -> A -> B vs Shop -> B -> A
          const order1 = currentBatch[0];
          const order2 = currentBatch[1];

          // Option A: Shop -> A -> B
          const distA1 = this.calculateHaversine(shopLat, shopLon, order1.address.latitude!, order1.address.longitude!);
          const distA2 = this.calculateHaversine(order1.address.latitude!, order1.address.longitude!, order2.address.latitude!, order2.address.longitude!);
          const costOptionA = distA1 + distA2;

          // Option B: Shop -> B -> A
          const distB1 = this.calculateHaversine(shopLat, shopLon, order2.address.latitude!, order2.address.longitude!);
          const distB2 = this.calculateHaversine(order2.address.latitude!, order2.address.longitude!, order1.address.latitude!, order1.address.longitude!);
          const costOptionB = distB1 + distB2;

          const optimalRoute: RouteStop[] = [
            { type: 'PICKUP', name: shopName, latitude: shopLat, longitude: shopLon }
          ];

          let totalDist = 0;
          if (costOptionA <= costOptionB) {
            totalDist = costOptionA;
            optimalRoute.push({ type: 'DELIVERY', name: `${order1.consumer.name} (${order1.address.title || 'Adres'})`, latitude: order1.address.latitude!, longitude: order1.address.longitude!, orderId: order1.id } as any);
            optimalRoute.push({ type: 'DELIVERY', name: `${order2.consumer.name} (${order2.address.title || 'Adres'})`, latitude: order2.address.latitude!, longitude: order2.address.longitude!, orderId: order2.id } as any);
          } else {
            totalDist = costOptionB;
            optimalRoute.push({ type: 'DELIVERY', name: `${order2.consumer.name} (${order2.address.title || 'Adres'})`, latitude: order2.address.latitude!, longitude: order2.address.longitude!, orderId: order2.id } as any);
            optimalRoute.push({ type: 'DELIVERY', name: `${order1.consumer.name} (${order1.address.title || 'Adres'})`, latitude: order1.address.latitude!, longitude: order1.address.longitude!, orderId: order1.id } as any);
          }

          recommendedBatches.push({
            shopId,
            shopName,
            orders: currentBatch.map(o => ({ id: o.id, consumerName: o.consumer.name ?? "Müşteri", status: o.status })),
            route: optimalRoute,
            totalDistanceKm: Number(totalDist.toFixed(2)),
            estimatedPrepTimeMins: estimatedPrepTime,
            totalCostScore: Number((totalDist + estimatedPrepTime / 10).toFixed(2))
          });
        }
      }
    }

    return recommendedBatches;
  }
}
