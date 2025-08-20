/**
 * Calculate percentage change between two values
 * @param first - Initial value
 * @param last - Final value
 * @returns Percentage change or null if calculation is invalid
 */
export const pctChange = (first: number, last: number): number | null => {
  if (!Number.isFinite(first) || !Number.isFinite(last) || first <= 0) {
    return null;
  }
  return ((last - first) / first) * 100;
};

/**
 * Find first and last valid prices from price array
 * @param prices - Array of [timestamp, price] tuples
 * @returns Object with first and last valid prices or null
 */
export function firstLastValid(
  prices: Array<[number, number]>,
): { first: number; last: number } | null {
  if (!Array.isArray(prices) || prices.length === 0) {
    return null;
  }

  // Find first valid price
  const first = prices.find(
    ([, price]) => Number.isFinite(price) && price > 0,
  )?.[1];

  // Find last valid price (search from end)
  const last = [...prices]
    .reverse()
    .find(([, price]) => Number.isFinite(price) && price > 0)?.[1];

  if (first != null && last != null) {
    return { first, last };
  }

  return null;
}
