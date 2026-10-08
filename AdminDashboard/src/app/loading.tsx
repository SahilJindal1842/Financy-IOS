import PageLoader from "@/components/PageLoader";

export default function Loading() {
  return (
    <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
      <PageLoader
        title="Loading workspace..."
        subtitle="Retrieving real-time dashboard data and preferences"
      />
    </div>
  );
}
