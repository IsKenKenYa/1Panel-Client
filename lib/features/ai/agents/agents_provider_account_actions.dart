part of 'agents_provider.dart';

extension AgentsProviderAccountActions on AgentsProvider {
  Future<bool> createAccount(AgentAccountCreateReq request) async {
    try {
      await _repository.createAccount(request);
      await _loadAccounts();
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'create account failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> updateAccount(AgentAccountUpdateReq request) async {
    try {
      await _repository.updateAccount(request);
      await _loadAccounts();
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'update account failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      await _repository.deleteAccount(id);
      await _loadAccounts();
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'delete account failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> verifyAccount(AgentAccountVerifyReq request) async {
    try {
      await _repository.verifyAccount(request);
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'verify account failed');
      _emitChange();
      return false;
    }
  }
}
