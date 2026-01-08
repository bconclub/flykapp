import 'package:connectivity_plus/connectivity_plus.dart';
import 'hive_service.dart';
import 'supabase_service.dart';

class SyncService {
  final HiveService _hiveService = HiveService();
  final SupabaseService _supabaseService = SupabaseService();
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncAll() async {
    if (!await isOnline()) return;
    // Auth check disabled - using test user_id
    // if (_supabaseService.currentUser == null) return;

    await syncIdeas();
    await syncIdeaLinks();
    await syncFlows();
  }

  Future<void> syncIdeas() async {
    final unsyncedIdeas = await _hiveService.getUnsyncedIdeas();
    
    for (var idea in unsyncedIdeas) {
      try {
        if (idea.id == null || idea.id!.startsWith('local_')) {
          // New idea - create in Supabase
          final syncedIdea = await _supabaseService.createIdea(idea);
          if (idea.id != null) {
            await _hiveService.deleteIdea(idea.id!);
          }
          syncedIdea.isSynced = true;
          await _hiveService.saveIdea(syncedIdea);
        } else {
          // Existing idea - update in Supabase
          final syncedIdea = await _supabaseService.updateIdea(idea);
          syncedIdea.isSynced = true;
          await _hiveService.saveIdea(syncedIdea);
        }
      } catch (e) {
        // Handle error - keep idea as unsynced
        print('Error syncing idea: $e');
      }
    }

    // Pull latest from Supabase
    try {
      final remoteIdeas = await _supabaseService.getIdeas();
      for (var remoteIdea in remoteIdeas) {
        final localIdea = await _hiveService.getIdea(remoteIdea.id!);
        if (localIdea == null || 
            localIdea.updatedAt == null ||
            remoteIdea.updatedAt == null ||
            remoteIdea.updatedAt!.isAfter(localIdea.updatedAt!)) {
          await _hiveService.saveIdea(remoteIdea);
        }
      }
    } catch (e) {
      print('Error pulling ideas: $e');
    }
  }

  Future<void> syncIdeaLinks() async {
    final unsyncedLinks = await _hiveService.getUnsyncedLinks();
    
    for (var link in unsyncedLinks) {
      try {
        if (link.id == null || link.id!.startsWith('local_')) {
          final syncedLink = await _supabaseService.createIdeaLink(link);
          if (link.id != null) {
            // Remove old local link if exists
            final box = await _hiveService.getLinksBox();
            await box.delete(link.id);
          }
          syncedLink.isSynced = true;
          await _hiveService.saveIdeaLink(syncedLink);
        }
      } catch (e) {
        print('Error syncing link: $e');
      }
    }

    // Pull latest links
    try {
      final remoteLinks = await _supabaseService.getAllIdeaLinks();
      for (var remoteLink in remoteLinks) {
        await _hiveService.saveIdeaLink(remoteLink);
      }
    } catch (e) {
      print('Error pulling links: $e');
    }
  }

  Future<void> syncFlows() async {
    final unsyncedFlows = await _hiveService.getUnsyncedFlows();
    
    for (var flow in unsyncedFlows) {
      try {
        if (flow.id == null || flow.id!.startsWith('local_')) {
          // New flow - create in Supabase
          final syncedFlow = await _supabaseService.createFlow(flow);
          if (flow.id != null) {
            await _hiveService.deleteFlow(flow.id!);
          }
          syncedFlow.isSynced = true;
          await _hiveService.saveFlow(syncedFlow);
        } else {
          // Existing flow - update in Supabase
          final syncedFlow = await _supabaseService.updateFlow(flow);
          syncedFlow.isSynced = true;
          await _hiveService.saveFlow(syncedFlow);
        }
      } catch (e) {
        print('Error syncing flow: $e');
      }
    }

    // Pull latest from Supabase
    try {
      final remoteFlows = await _supabaseService.getFlows();
      for (var remoteFlow in remoteFlows) {
        final localFlow = await _hiveService.getFlow(remoteFlow.id!);
        if (localFlow == null || 
            remoteFlow.createdAt.isAfter(localFlow.createdAt)) {
          await _hiveService.saveFlow(remoteFlow);
        }
      }
    } catch (e) {
      print('Error pulling flows: $e');
    }
  }
}

