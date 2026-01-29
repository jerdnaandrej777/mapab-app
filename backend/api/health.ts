import type { VercelRequest, VercelResponse } from '@vercel/node';

export default async function handler(_req: VercelRequest, res: VercelResponse) {
  const hasOpenAIKey = !!process.env.OPENAI_API_KEY;

  return res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    services: {
      openai: hasOpenAIKey ? 'configured' : 'missing',
    },
    version: '1.0.0',
  });
}
