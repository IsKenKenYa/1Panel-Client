/**
 * @syscap SystemCapability.Notification.Notification
 * @crossplatform
 */
declare namespace notificationManager {
  function publish(request: object): void;
  function cancel(id: number): void;
}
export default notificationManager;
