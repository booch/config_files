import { ChiefError } from "./context";

const MAX_SLUG = 40;
// Becomes a branch name and a path segment: no slashes, dots, or leading hyphen.
const SLUG = new RegExp(`^[a-z0-9][a-z0-9-]{0,${MAX_SLUG - 1}}$`);

export function slugify(goal: string): string {
    const slug = goal
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .slice(0, MAX_SLUG)
        .replace(/^-+|-+$/g, "");
    if (!slug) throw new ChiefError(`cannot derive a slug from "${goal}"; pass --slug`);
    return slug;
}

export function validateSlug(slug: string): string {
    if (!SLUG.test(slug))
        throw new ChiefError(`invalid slug "${slug}": use lowercase letters, digits, and hyphens`);
    return slug;
}
