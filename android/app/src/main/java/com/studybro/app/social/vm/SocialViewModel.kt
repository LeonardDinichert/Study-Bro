package com.studybro.app.social.vm

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.studybro.app.social.repo.SocialRepository
import com.studybro.app.user.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class SocialViewModel(private val repo: SocialRepository = SocialRepository()) : ViewModel() {
    private val _friends = MutableStateFlow<List<User>>(emptyList())
    val friends: StateFlow<List<User>> = _friends
    private val _pending = MutableStateFlow<List<User>>(emptyList())
    val pending: StateFlow<List<User>> = _pending

    init {
        val uid = com.studybro.app.core.di.FirebaseModule.auth.currentUser?.uid ?: return
        repo.listenUser(uid) { user ->
            _friends.value = user?.friends?.map { User(uid = it) } ?: emptyList()
            _pending.value = user?.pendingFriends?.map { User(uid = it) } ?: emptyList()
        }
    }

    fun sendRequest(targetUid: String) {
        viewModelScope.launch { repo.sendFriendRequest(targetUid) }
    }

    fun accept(fromUid: String) {
        viewModelScope.launch { repo.acceptFriendRequest(fromUid) }
    }

    fun decline(fromUid: String) {
        viewModelScope.launch { repo.declineFriendRequest(fromUid) }
    }

    suspend fun searchByEmail(email: String): User? = repo.searchUserByEmail(email)
}
