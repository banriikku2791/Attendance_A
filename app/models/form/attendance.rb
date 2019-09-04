class Form::Attendance < Attendance

  REGISTRABLE_ATTRIBUTES = %i(
    note
    end_at(1i) end_at(2i) end_at(3i) end_at(4i) end_at(5i)
    request_end
  )

  REGISTRABLE_ATTRIBUTES_2 = %i(
    reason
    started_at(1i) started_at(2i) started_at(3i) started_at(4i) started_at(5i)
    finished_at(1i) finished_at(2i) finished_at(3i) finished_at(4i) finished_at(5i)
    request_change
  )

end