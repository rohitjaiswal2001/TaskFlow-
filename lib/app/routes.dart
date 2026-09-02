abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const lock = '/lock';

  static const home = '/home';
  static const projects = '/projects';
  static const tasks = '/tasks';
  static const profile = '/profile';

  static const newProject = '/projects/new';
  static const projectDetail = '/projects/:projectId';
  static const projectEdit = '/projects/:projectId/edit';

  static const newTask = '/tasks/new';
  static const taskDetail = '/tasks/:taskId';
  static const taskEdit = '/tasks/:taskId/edit';

  static const notifications = '/notifications';
  static const developer = '/developer';

  static String projectDetailOf(String projectId) => '/projects/$projectId';

  static String projectEditOf(String projectId) => '/projects/$projectId/edit';

  static String taskDetailOf(String taskId) => '/tasks/$taskId';

  static String taskEditOf(String taskId) => '/tasks/$taskId/edit';

  static String newTaskIn(String? projectId) =>
      projectId == null ? newTask : '$newTask?projectId=$projectId';
}
