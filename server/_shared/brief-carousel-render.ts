/**
 * Brief carousel image renderer (Phase 8).
 *
 * Given a BriefEnvelope and a page index in {0, 1, 2}, builds a
 * Satori layout tree and hands it to @vercel/og's ImageResponse,
 * which rasterises to a 1200×630 PNG and returns a Response ready
 * to ship. The output is the standard OG size that Telegram /
 * Slack / Discord all preview well.
 *
 * Design choices:
 *  - @vercel/og wraps satori + resvg-wasm with Vercel-native
 *    bundling. Runs on Edge runtime. No native Node binding needed,
 *    no manual `includeFiles` trick in vercel.json. (Previous
 *    attempts: direct satori + @resvg/resvg-wasm hit edge-bundler
 *    asset-URL errors; direct satori + @resvg/resvg-js native
 *    binding hit FUNCTION_INVOCATION_FAILED because nft never
 *    traced the platform-conditional peer package. See PR history
 *    on #3174 / #3196 / #3204 / #3206 for the full arc.)
 *  - Page templates are simplified versions of the magazine's
 *    cover / threads / first-story pages. They are not pixel-matched
 *    — the carousel is a teaser, not a replacement for the HTML.
 *  - The renderer relies on @vercel/og's bundled default font so it
 *    can render in tests and edge isolates without a runtime network
 *    dependency. The edge route layer owns HMAC verification + Redis
 *    lookup.
 */

import { ImageResponse } from '@vercel/og';

// ── Colour palette (must match magazine's aesthetic) ───────────────────────

const COLORS = {
  ink: '#0a0a0a',
  bone: '#f2ede4',
  cream: '#f1e9d8',
  creamInk: '#1a1612',
  sienna: '#8b3a1f',
  paper: '#fafafa',
  paperInk: '#0a0a0a',
} as const;

// ── Layouts ────────────────────────────────────────────────────────────────

type Envelope = {
  version: number;
  issuedAt: number;
  data: {
    issue: string;
    dateLong: string;
    user?: { name?: string };
    digest: {
      greeting: string;
      lead: string;
      threads: Array<{ tag: string; teaser: string }>;
    };
    stories: Array<{
      category: string;
      country: string;
      threatLevel: string;
      headline: string;
      source: string;
    }>;
  };
};

export type CarouselPage = 'cover' | 'threads' | 'story';

export function pageFromIndex(i: number): CarouselPage | null {
  if (i === 0) return 'cover';
  if (i === 1) return 'threads';
  if (i === 2) return 'story';
  return null;
}

/* eslint-disable @typescript-eslint/no-explicit-any */
function buildCover(env: Envelope): any {
  const { data } = env;
  return {
    type: 'div',
    props: {
      style: {
        width: 1200, height: 630,
        backgroundColor: COLORS.ink,
        color: COLORS.bone,
        display: 'flex', flexDirection: 'column',
        padding: '60px 72px',
      },
      children: [
        {
          type: 'div',
          props: {
            style: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', opacity: 0.75, fontSize: 18, letterSpacing: '0.2em', textTransform: 'uppercase' },
            children: ['WORLDMONITOR', `ISSUE Nº ${data.issue}`],
          },
        },
        {
          type: 'div',
          props: {
            style: { flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' },
            children: [
              {
                type: 'div',
                props: {
                  style: { fontSize: 20, letterSpacing: '0.3em', textTransform: 'uppercase', opacity: 0.7, marginBottom: 32 },
                  children: data.dateLong,
                },
              },
              {
                type: 'div',
                props: {
                  style: { fontSize: 140, lineHeight: 0.92, fontWeight: 900, letterSpacing: '-0.02em' },
                  children: 'WorldMonitor',
                },
              },
              {
                type: 'div',
                props: {
                  style: { fontSize: 140, lineHeight: 0.92, fontWeight: 900, letterSpacing: '-0.02em', marginBottom: 36 },
                  children: 'Brief.',
                },
              },
              {
                type: 'div',
                props: {
                  style: { fontSize: 28, fontStyle: 'italic', opacity: 0.8, maxWidth: 900 },
                  children: `${data.stories.length} ${data.stories.length === 1 ? 'thread' : 'threads'} that shaped the world today.`,
                },
              },
            ],
          },
        },
        {
          type: 'div',
          props: {
            style: { display: 'flex', justifyContent: 'space-between', opacity: 0.6, fontSize: 16, letterSpacing: '0.2em', textTransform: 'uppercase' },
            children: [data.digest.greeting, 'Open for full brief →'],
          },
        },
      ],
    },
  };
}

function buildThreads(env: Envelope): any {
  const { data } = env;
  const threads = data.digest.threads.slice(0, 5);
  return {
    type: 'div',
    props: {
      style: {
        width: 1200, height: 630,
        backgroundColor: COLORS.cream,
        color: COLORS.creamInk,
        display: 'flex', flexDirection: 'column',
        padding: '60px 72px',
      },
      children: [
        {
          type: 'div',
          props: {
            style: { display: 'flex', justifyContent: 'space-between', borderBottom: `1px solid ${COLORS.sienna}40`, paddingBottom: 14, fontSize: 16, letterSpacing: '0.2em', textTransform: 'uppercase', color: COLORS.sienna, fontWeight: 600 },
            children: [`· WorldMonitor Brief · ${data.issue} ·`, 'Digest / On The Desk'],
          },
        },
        {
          type: 'div',
          props: {
            style: { flex: 1, display: 'flex', flexDirection: 'column', paddingTop: 40 },
            children: [
              {
                type: 'div',
                props: {
                  style: { color: COLORS.sienna, fontSize: 20, letterSpacing: '0.3em', textTransform: 'uppercase', marginBottom: 30 },
                  children: "Today's Threads",
                },
              },
              {
                type: 'div',
                props: {
                  style: { fontSize: 80, lineHeight: 1.0, fontWeight: 900, letterSpacing: '-0.015em', marginBottom: 50, maxWidth: 1000 },
                  children: 'What the desk is watching.',
                },
              },
              {
                type: 'div',
                props: {
                  style: { display: 'flex', flexDirection: 'column', gap: 20 },
                  children: threads.map((t) => ({
                    type: 'div',
                    props: {
                      style: { display: 'flex', alignItems: 'baseline', gap: 16, fontSize: 26, lineHeight: 1.3 },
                      children: [
                        {
                          type: 'div',
                          props: {
                            style: { color: COLORS.sienna, fontSize: 18, fontWeight: 600, letterSpacing: '0.2em', textTransform: 'uppercase', flexShrink: 0 },
                            children: `${t.tag} —`,
                          },
                        },
                        {
                          type: 'div',
                          props: { style: { flex: 1 }, children: t.teaser },
                        },
                      ],
                    },
                  })),
                },
              },
            ],
          },
        },
      ],
    },
  };
}

function buildStory(env: Envelope): any {
  const { data } = env;
  const story = data.stories[0];
  if (!story) return buildCover(env);
  return {
    type: 'div',
    props: {
      style: {
        width: 1200, height: 630,
        backgroundColor: COLORS.paper,
        color: COLORS.paperInk,
        display: 'flex',
        padding: '60px 72px',
      },
      children: [
        {
          type: 'div',
          props: {
            style: { flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', position: 'relative' },
            children: [
              {
                type: 'div',
                props: {
                  style: { display: 'flex', gap: 14, marginBottom: 36 },
                  children: [
                    {
                      type: 'div',
                      props: {
                        style: { border: `1px solid ${COLORS.paperInk}`, padding: '8px 16px', fontSize: 16, letterSpacing: '0.22em', textTransform: 'uppercase', fontWeight: 600 },
                        children: story.category,
                      },
                    },
                    {
                      type: 'div',
                      props: {
                        style: { border: `1px solid ${COLORS.paperInk}`, padding: '8px 16px', fontSize: 16, letterSpacing: '0.22em', textTransform: 'uppercase', fontWeight: 600 },
                        children: story.country,
                      },
                    },
                    {
                      type: 'div',
                      props: {
                        style: { backgroundColor: COLORS.paperInk, color: COLORS.paper, padding: '8px 16px', fontSize: 16, letterSpacing: '0.22em', textTransform: 'uppercase', fontWeight: 600 },
                        children: story.threatLevel,
                      },
                    },
                  ],
                },
              },
              {
                type: 'div',
                props: {
                  style: { fontSize: 64, lineHeight: 1.02, fontWeight: 900, letterSpacing: '-0.02em', marginBottom: 36, maxWidth: 900 },
                  children: story.headline.slice(0, 160),
                },
              },
              {
                type: 'div',
                props: {
                  style: { fontSize: 20, letterSpacing: '0.2em', textTransform: 'uppercase', opacity: 0.6 },
                  children: `Source · ${story.source}`,
                },
              },
            ],
          },
        },
      ],
    },
  };
}

// ── Public API ─────────────────────────────────────────────────────────────

/**
 * Render a single page of the carousel into an ImageResponse.
 * Throws on structurally unusable envelope — callers (the edge route)
 * should catch + return 503 no-store so Vercel's CDN + Telegram's
 * media fetcher don't pin a bad render.
 */
export async function renderCarouselImageResponse(
  envelope: Envelope,
  page: CarouselPage,
  extraHeaders: Record<string, string> = {},
): Promise<ImageResponse> {
  if (!envelope?.data) throw new Error('invalid envelope');

  const tree =
    page === 'cover' ? buildCover(envelope) :
    page === 'threads' ? buildThreads(envelope) :
    buildStory(envelope);

  return new ImageResponse(tree, {
    width: 1200,
    height: 630,
    headers: extraHeaders,
  });
}
