<?php
class game_model extends CI_Model {

	public function __construct()
	{
		$this->load->database();
		
		
	}
	
	public function get_user_and_pass($user = FALSE)
	{
		if ($user === FALSE)
		{
			$query = $this->db->get('accounts');
			return $query->result_array();
		}

		$query = $this->db->get_where('accounts', array('username' => $user));
		return $query->row_array();
		
	}
	
	public function index()
	{
		echo 'moo';
		$data['user'] = array('user' => 'bar', 'text' => 'fuck'); //$this->news_model->get_news();
		$data['pass'] = 'Credentials';

		$this->load->view('templates/header', $data);
		$this->load->view('game/index', $data);
		$this->load->view('templates/footer');
	}
	
	public function submit_username_and_passwor()
	{
		$this->load->helper('url');

		$user = url_title($this->input->post('title'), '_', TRUE);

		$data = array(
			'user' => $this->input->post('title'),
			'pass' => $slug,
			'text' => $this->input->post('text')
			);

		return $this->db->insert('news', $data);
	}
	
}
