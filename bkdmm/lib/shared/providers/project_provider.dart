// Export the comprehensive project provider from features
export '../../features/project/providers/project_notifier.dart';

// Keep backward compatibility by also providing these aliases
// These are provided by the exported file above:
// - projectNotifierProvider (main provider)
// - currentProjectProvider
// - isProjectDirtyProvider
// - isProjectLoadingProvider
// - projectErrorProvider
// - projectStatisticsProvider
// - recentProjectsProvider
// - projectPathProvider
// - canSaveProjectProvider
// - canSaveProjectAsProvider