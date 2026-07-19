import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Response } from 'express';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const httpContext = context.switchToHttp();
    const request = httpContext.getRequest();
    const response = httpContext.getResponse<Response>();
    const method = request.method;
    const url = request.url;
    const now = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const delay = Date.now() - now;
          this.logger.log(
            `${method} ${url} ${response.statusCode} - ${delay}ms`,
          );
        },
        error: (err) => {
          const delay = Date.now() - now;
          const status =
            err instanceof Object && 'status' in err ? (err as any).status : 500;
          this.logger.error(
            `${method} ${url} ${status} - ${delay}ms - Error: ${
              err instanceof Error ? err.message : JSON.stringify(err)
            }`,
          );
        },
      }),
    );
  }
}
