import EntryPageContent from "@/components/entry/EntryPageContent";

export default async function EntryPage(props: {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const searchParams = (await props.searchParams) ?? {};
  const from = Array.isArray(searchParams.from)
    ? searchParams.from[0]
    : searchParams.from;

  return <EntryPageContent showHeader autoRedirectToChat={from !== "chat"} />;
}
