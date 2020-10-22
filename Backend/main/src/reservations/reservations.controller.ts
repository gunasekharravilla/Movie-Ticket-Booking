import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard';
import { GetUser, UserPayload } from '../auth/get-user.decorator';
import { CreateReservationDto } from './reservation.dto';
import { ReservationsService } from './reservations.service';
import { Reservation } from './reservation.schema';
import { PaginationDto } from '../common/pagination.dto';

@ApiTags('reservations')
@UseGuards(AuthGuard)
@Controller('reservations')
export class ReservationsController {
  constructor(
      private readonly reservationsService: ReservationsService,
  ) {}

  @Post()
  createReservation(
      @GetUser() userPayload: UserPayload,
      @Body() dto: CreateReservationDto,
  ): Promise<Reservation> {
    return this.reservationsService.createReservation(
        userPayload,
        dto,
    );
  }

  @Get()
  getReservations(
      @GetUser() userPayload: UserPayload,
      @Query() dto: PaginationDto,
  ) {
    return this.reservationsService.getReservations(
        userPayload,
        dto,
    );
  }
}
