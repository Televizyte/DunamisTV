import 'package:flutter/foundation.dart';

import '../data/kingdom_builder_save_repository.dart';
import '../domain/kingdom_builder_state.dart';

class KingdomBuilderController extends ChangeNotifier {
  final KingdomBuilderSaveRepository repository;

  KingdomBuilderController({KingdomBuilderSaveRepository? repository})
      : repository = repository ?? KingdomBuilderSaveRepository();

  KingdomBuilderState? _state;
  bool _loading = false;
  String? _error;

  KingdomBuilderState? get state => _state;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialise() async {
    if (_loading || _state != null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _state = await repository.load();
    } catch (error) {
      _error = error.toString();
      _state = KingdomBuilderState.initial();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> startFoundation() async {
    final current = _state;
    if (current == null || current.foundationStarted) return;
    _state = current.copyWith(
      foundationStarted: true,
      ministryFunds: current.ministryFunds - 500,
      faith: current.faith + 5,
      impact: current.impact + 2,
    );
    notifyListeners();
    await repository.save(_state!);
  }

  Future<void> welcomeVisitors() async {
    final current = _state;
    if (current == null || !current.foundationStarted) return;
    _state = current.copyWith(
      members: current.members + 2,
      faith: current.faith + 1,
      impact: current.impact + 1,
    );
    notifyListeners();
    await repository.save(_state!);
  }

  Future<void> reset() async {
    await repository.reset();
    _state = KingdomBuilderState.initial();
    await repository.save(_state!);
    notifyListeners();
  }
}
