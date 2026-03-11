import rss from '@astrojs/rss';
import { getPublishedPosts } from '../utils/content';

export async function GET(context: { site: URL }) {
  const posts = await getPublishedPosts();

  return rss({
    title: 'epoch-chrono',
    description: 'SRE & platform engineer. Blog técnico, TIL e projetos open source.',
    site: context.site,
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.pubDate,
      link: `/blog/${post.id}`,
    })),
  });
}
