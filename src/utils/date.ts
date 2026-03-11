// src/utils/date.ts — helpers de formatação de data

/**
 * Formata uma data para exibição em pt-BR.
 * Ex: "15 jan 2024"
 */
export function formatDate(date: Date, lang: 'pt-BR' | 'en' = 'pt-BR'): string {
  return date.toLocaleDateString(lang, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    timeZone: 'America/Sao_Paulo',
  });
}

/**
 * Formata uma data para ISO 8601 (usado em sitemaps, feeds RSS).
 */
export function toISOString(date: Date): string {
  return date.toISOString();
}

/**
 * Estima tempo de leitura em minutos.
 * Baseado em ~200 palavras/min para conteúdo técnico.
 */
export function readingTime(content: string): number {
  const words = content.trim().split(/\s+/).length;
  return Math.max(1, Math.round(words / 200));
}
