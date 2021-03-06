#include "IpcWrapper.hh"
#include "IpcHelper.hh"
#include <pthread.h>
#include <signal.h>
#include <unistd.h>
#include <string>
#include "Timer.hh"


bool __ipcWrapperThreadRunning = false;
bool __ipcWrapperConnected     = false;
pthread_t __ipcWrapperThread;
pthread_mutex_t __ipcWrapperActionRequestMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t __ipcWrapperActionMutex        = PTHREAD_MUTEX_INITIALIZER;

pthread_cond_t  __ipcWrapperActionCond  = PTHREAD_COND_INITIALIZER;
//pthread_cond_t  __ipcWrapperSendCond     = PTHREAD_COND_INITIALIZER;

int __ipcWrapperNumPendingActions = 0;
int __ipcWrapperSleepUs = 100;

Upenn::Timer __ipcTimer;


#define __IPC_WRAPPER_GET_SEND_LOCK_RETRIES 3

using namespace std;
using namespace Upenn;


int __IpcWrapperCheckPendingActions()
{
  int nActions;
  int ret;
  ret = pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  if (ret) return -1;

  nActions = __ipcWrapperNumPendingActions;
  
  ret = pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
  if (ret) return -2;

  return nActions;
}

void *__IpcWrapperThreadFunc(void * input)
{
  int ret;

  sigset_t sigs;
	sigfillset(&sigs);
	pthread_sigmask(SIG_BLOCK,&sigs,NULL);

  ret = pthread_mutex_lock( &__ipcWrapperActionMutex );

  while(true)
  {
    //see if we need to cancel the thread		
    pthread_testcancel();

    int nPendingActions = __IpcWrapperCheckPendingActions();

    while (nPendingActions > 0)
    {
      //wait until all the pending actions are executed
      ret = pthread_cond_wait(&__ipcWrapperActionCond,&__ipcWrapperActionMutex);

      //FIXME: what do we do if pthread_cond_wait fails and does not re-lock the mutex???

      //verify that the number of pending actions is actually zero,
      //since pthread_cond_wait can wake up on its own
      nPendingActions = __IpcWrapperCheckPendingActions();
    }

    __ipcTimer.Tic();
    //IPC_listenClear(0);
    IPC_listen(0);
    usleep(__ipcWrapperSleepUs);

    //double dt= __ipcTimer.Toc();
    //printf("ipc waited %f seconds \n",dt); fflush(stdout);
  }

  return NULL;
}

int __IpcWrapperStartThread()
{
  int ret;
  ret = pthread_create(&__ipcWrapperThread,NULL,__IpcWrapperThreadFunc, NULL);
  __ipcWrapperThreadRunning = true;
  return ret;
}


int __IpcWrapperGetActionLock()
{
  int ret;

  ret = pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  if (ret) return -1;

  __ipcWrapperNumPendingActions++;
  
  ret = pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
  if (ret) return -2;

  ret = pthread_mutex_lock( &__ipcWrapperActionMutex );
  if (ret) return -3;
  else return 0;
}

int __IpcWrapperReleaseActionLock()
{
  int ret;

  ret = pthread_mutex_lock( &__ipcWrapperActionRequestMutex );
  if (ret) return -1;

  __ipcWrapperNumPendingActions--;


  //signal that there are no more pending actions
  if (__ipcWrapperNumPendingActions == 0)
  {
    ret = pthread_cond_signal(&__ipcWrapperActionCond);
    if (ret) return -2;
  }

  ret = pthread_mutex_unlock( &__ipcWrapperActionMutex );
  if (ret) return -3;
  
  ret = pthread_mutex_unlock( &__ipcWrapperActionRequestMutex );
  if (ret) return -4;
  
  else return 0;
}



int IpcWrapperConnect(string taskName, 
                      string serverName,
                      bool multiThread)
{
  //check if already connected
  if (__ipcWrapperConnected)
    return 0;

  //set the verbosity to printing errors, so that ipc does not exit on errors
  IPC_setVerbosity(IPC_Print_Errors);

  
  //generate a unique process name and connect
  int ret = IPC_connectModule(IpcHelper::GetProcessName(taskName).c_str(), 
                              serverName.c_str());
  
  if (ret == IPC_OK)
  {
    printf("connected to ipc\n");

    if (multiThread)
    {
      ret = __IpcWrapperStartThread();
      if ( ret != 0) return -2;
      printf("started thread\n");
    }

    __ipcWrapperConnected = true;
    return 0;
  }
  else return -1;
}


bool IpcWrapperIsConnected()
{
 return __ipcWrapperConnected;
}

int IpcWrapperDisconnect()
{
  if (!__ipcWrapperConnected)
    return 0;


  //TODO: implement proper disconnect procedure

  return 0;
}



int IpcWrapperDefineMsg(string msgName, string formatString)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  char * fmt = NULL;
  if (!formatString.empty())
    fmt = (char*)formatString.c_str();

  int ret2 = IPC_defineMsg(msgName.c_str(), IPC_VARIABLE_LENGTH, fmt);

  ret = __IpcWrapperReleaseActionLock();
  
  if (ret) return -2;

  if (ret2 != IPC_OK) return 3;
  else return 0;
}



int IpcWrapperPublish(string msgName, unsigned int length,
                      BYTE_ARRAY content)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_publish(msgName.c_str(),length,content);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperPublishData(string msgName, void * data)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_publishData(msgName.c_str(),data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}


int IpcWrapperSubscribe(string msgName, HANDLER_TYPE handler,
                        void * clientData)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_subscribe(msgName.c_str(),handler,clientData);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperSubscribeData(string msgName, HANDLER_DATA_TYPE handler,
                        void * clientData)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_subscribeData(msgName.c_str(),handler,clientData);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperUnsubscribe(string msgName, HANDLER_TYPE handler)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_unsubscribe(msgName.c_str(),handler);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperQueryResponseData(const char * msgName, void * data,
                                void ** replyData, unsigned int timeoutMsecs)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_queryResponseData(msgName,data,replyData,timeoutMsecs);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}


int IpcWrapperFreeData(const char * format, void * data)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IpcWrapperFreeData(IPC_parseFormat(format),data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperFreeData(FORMATTER_PTR formatter, void * data)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_freeData(formatter,data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}

int IpcWrapperFreeByteArray(void * data)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  IPC_freeByteArray(data);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;
  else return 0;
}

int IpcWrapperSetMsgQueueLength(string msgName, int length)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_setMsgQueueLength((char*)msgName.c_str(),length);

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  if (ret2 != IPC_OK) return -3;
  else return 0;
}


int IpcWrapperNumHandlers(string msgName)
{
  int ret = __IpcWrapperGetActionLock();
  if (ret) return -1;

  int ret2 = IPC_numHandlers((char*)msgName.c_str());

  ret = __IpcWrapperReleaseActionLock();
  if (ret) return -2;

  return ret2;
}

int IpcWrapperListenWait(int milliseconds)
{
  if (__ipcWrapperThreadRunning)
    return -1;

  int ret = IPC_listenWait(milliseconds);

  if (ret != IPC_OK)
    return -1;
  return 0;
}



