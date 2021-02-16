#ifndef _PTHREAD_H
#define _PTHREAD_H
#ifdef __cplusplus
extern "C" {
#endif

#define __NEED_time_t
#define __NEED_clockid_t
#define __NEED_struct_timespec
#define __NEED_sigset_t
#define __NEED_pthread_t
#define __NEED_pthread_attr_t
#define __NEED_pthread_mutexattr_t
#define __NEED_pthread_condattr_t
#define __NEED_pthread_rwlockattr_t
#define __NEED_pthread_barrierattr_t
#define __NEED_pthread_mutex_t
#define __NEED_pthread_cond_t
#define __NEED_pthread_rwlock_t
#define __NEED_pthread_barrier_t
#define __NEED_pthread_spinlock_t
#define __NEED_pthread_key_t
#define __NEED_pthread_once_t
#define __NEED_size_t

#include <errno.h>
#include <bits/alltypes.h>

#define _WASM_LIBC_PTHREAD_ABI_VISIBILITY inline

#define PTHREAD_MUTEX_NORMAL 0
#define PTHREAD_MUTEX_DEFAULT 0
#define PTHREAD_MUTEX_RECURSIVE 1
#define PTHREAD_MUTEX_ERRORCHECK 2

#define PTHREAD_MUTEX_INITIALIZER {{{0}}}
#define PTHREAD_RWLOCK_INITIALIZER 0
#define PTHREAD_COND_INITIALIZER {{{0}}}
#define PTHREAD_ONCE_INIT 0

// Mutex
_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *attr) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutex_destroy(pthread_mutex_t *mutex) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutexattr_init(pthread_mutexattr_t *attr) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutexattr_destroy(pthread_mutexattr_t *attr) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutexattr_gettype(const pthread_mutexattr_t *attr, int *type) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int type) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutex_lock(pthread_mutex_t *mutex) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutex_trylock(pthread_mutex_t *mutex) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_mutex_unlock(pthread_mutex_t *mutex) {
  return 0;
}

// Condition variable
_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_cond_destroy(pthread_cond_t *cond) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_cond_timedwait(pthread_cond_t *cond, pthread_mutex_t *mutex, const struct timespec *abstime) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_cond_broadcast(pthread_cond_t *cond) {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_cond_signal(pthread_cond_t *cond) {
  return 0;
}


// Thread local storage
_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_key_create(pthread_key_t *key, void (*destructor)(void*)) {
  return EAGAIN;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
void *pthread_getspecific(pthread_key_t key) {
  return NULL;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_setspecific(pthread_key_t key, const void *value) {
  return EINVAL;
}


// Thread
_WASM_LIBC_PTHREAD_ABI_VISIBILITY
pthread_t pthread_self() {
  return 0;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_equal(pthread_t t1, pthread_t t2) {
  return t1 == t2;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_join(pthread_t thread, void **value_ptr) {
  return ESRCH;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_detach(pthread_t thread) {
  return ESRCH;
}

_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine)(void *), void *arg) {
  return EAGAIN;
}

// Execute once
_WASM_LIBC_PTHREAD_ABI_VISIBILITY
int pthread_once(pthread_once_t *flag, void (*init_routine)(void)) {
  if (! *flag) {
    *flag = 1;
    init_routine();
  }
  return 0;
}

#ifdef __cplusplus
}
#endif
#endif
